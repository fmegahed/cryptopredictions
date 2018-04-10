from bs4 import BeautifulSoup
import re, requests, csv, time
from comment_threads import get_authenticated_service, get_comments
from oauth2client.tools import argparser, run_flow

import sys  
reload(sys)  
sys.setdefaultencoding('utf-8')

""" scrape youtube channel to build table of contents html file and 
    csv of video information for excel file
    note this code has a slow down delay to meet youtube terms of use
"""

# set youtube channel name here
channel_name = ""
youtube = ""

def get_soup(url):
    """open url and return BeautifulSoup object, or None if site does not exist"""
    result = requests.get(url)
    if result.status_code != 200: return None
    time.sleep(5) # slow down as per youtube 'terms of use' to human speed
    return BeautifulSoup(result.text, 'html.parser')

def channel_section_links():
    '''list of { 'title': <section title>, 'link': <url to section play lists> }'''
    soup = get_soup("https://www.youtube.com/user/"+channel_name+"/playlists")
    print "https://www.youtube.com/channel/"+channel_name+"/playlists"
    if 'This channel does not exist.' in soup.text:
        raise ValueError("The channel does not exists: " + channel_name)

    play_list_atags = soup.find_all('a', {'href': re.compile(channel_name+"/playlists")})
    elements = [{'title': x.text.strip(), "link": fix_url(x['href'])} for x in play_list_atags if
                x.span and ('shelf_id=0' not in x['href'])] # filter out non user play lists

    if len(elements) == 0: # no sections, make up no sections section with default link
        elements = [ {'title':'no sections',
                      'link':'https://youtube.com/'+channel_name+'/playlists'}]

    return elements


def fix_url(url):  # correct relative urls back to absolute urls
    if url[0] == '/': return 'https://www.youtube.com' + url
    else: return url


def get_playlists(section):
    """returns list of list of { 'title': <playlist tile>, <link to all playlist videos> }"""
    print("  getting playlists for section: " + section['title'])
    soup = get_soup(section['link'])
    if soup == None: # no playlist, create dummy playlist and default link
       return [{'title':'No Playlists', 'link':'https://youtube.com/'+channel_name+'/videos'}]
    atags = soup('a', class_="yt-uix-tile-link")

    playlists = []
    for a in atags:  # find title and link
        title = a.text
        if title != "Liked videos": # skip these
            link = fix_url(a['href'])
            playlists.append({'title':title, 'link':link})
    if playlists == []: return [{'title':'No Playlists',
                                 'link':'https://youtube.com/'+channel_name+'/videos'}]
    return playlists

def add_videos(playlist):
    """find videos in playlist[link] and add their info as playlist[videos] as list"""
    soup = get_soup(playlist['link'])
    print("    getting videos for playlist: " + playlist['title'])
    items = soup('a', class_="yt-uix-tile-link") # items are list of video a links from list
    videos = []
    for i in items: # note first part of look get info from playlist page item, and the the last part opens
                    # the video and gets more details
        d = {} # collect video info in dict
        try:
            d['title'] = i.text.strip()
            link = fix_url(i['href'])
            d['link'] = link

            print link
            
            t = i.find_next('span', { 'aria-label': True})
            d['time'] = t.text if t else 'NA'
            print("      open video " + d['title'] + " for details",)

            vsoup = get_soup(link) # now get video page and pull information from it
            print("* read, now processing",)
            
            
            views= vsoup.find('div', class_='watch-view-count').text
            d['views'] = ''.join(c for c in views if c in "0123456789")
             
            

            d['publication_date'] = vsoup.find('strong',
                                    class_="watch-time-text").text[len('Published on ')-1:]
            d['description'] = vsoup.find('div',id='watch-description-text').text
            id = vsoup.find('meta', itemprop="videoId")['content']
            d['id'] = id
            likebutton = vsoup.find('button', class_="like-button-renderer-like-button")
            o = likebutton.find('span',class_ = 'yt-uix-button-content')
            d['likes'] = o.text if o else ""
            disbutton = vsoup.find('button',class_='like-button-renderer-dislike-button')
            o = disbutton.find('span',class_ = 'yt-uix-button-content')
            d['dislikes'] = o.text if o else ""
            videos.append(d)
            print("* finished video")

            playlist['videos'] = videos # add new key to this playlist of list of video infos
        except:
            d['views'] = -100

def tag(t,c): return '<' + t + '>' + c + '</'+t+'>' # return html tag with content
def link(text, url): return '<a href=' + url +'>' + text +'</a>' # return a tag with content and link

def csv_out(channel, sections):
    """ create and output channel_name.csv file for import into a spreadsheet or DB"""
    headers = 'channel,section,playlist,video,' \
              'link,time,views,publication date,likes,dislikes,description'.split(',')

    with open(channel+'.csv', "w") as csv_file:
        csvf = csv.writer(csv_file, delimiter=',')
        csvf.writerow(headers)
        for section in sections:
            for playlist in section['playlists']:
                for video in playlist['videos']:
                    v = video
                    line = [ channel, section['title'], playlist['title'], v['title']]
                    line.extend([v['id'],v['time'], v['views'], v['publication_date'],
                                 v['likes'], v['dislikes'], v['description']])

                    video_comments = get_comments(youtube, v['id'], None)
                    for comment in video_comments:
                        # print comment
                        temp_line = line + comment
                        csvf.writerow(temp_line)
                    # print line
                    csvf.writerow(line)

if __name__ == '__main__':
    # find channel name by going to channel and picking last element from channel url
    # for example my channel url is: https://www.youtube.com/user/gjenkinslbcc
    # my channel name is gjenkinslbcc in this url
    # this is set near top of this file

    argparser.add_argument("--channelid",
    help="Required; ID for channel for which the comment will be inserted.")
    
    args = argparser.parse_args()
    if not args.channelid:
        exit("Please specify channelid using the --channelid= parameter.")
  
    channel_name = args.channelid

    print("finding sections")
    sections = channel_section_links()
    
    youtube = get_authenticated_service(args)

    for section in sections:
        section['playlists'] = get_playlists(section)
        print section['playlists']
        for playlist in section['playlists']:
            add_videos(playlist)

    csv_out(channel_name, sections) # create a csv file of video info for import into spreadsheet

    print("Program Complete,\n"  + channel_name+".csv have been written to current directory")