#!/usr/bin/env python

from bs4 import BeautifulSoup
from base64 import b64encode
from collections import namedtuple

import requests
import os
import zlib
import json
import string


def download_img(url, compress=True):
    r = requests.get(url)

    if r.status_code != requests.codes.ok:
        r.raise_for_status()

    data = zlib.compress(r.content) if compress else r.content
    return b64encode(data).decode('utf-8')


def extract_description(soup):
    description = None
    try:
        #description = extract_description(soup)
        pass
    except Exception as e:
        print("ERROR: An error occured while attempting to extract a description -- {0}".format(e))
    else:
        if not description:
            print("WARNING: Description could not be found.")
    finally:
        return description


def extract_list_items(soup):
    items = []

    try:
        # Find list items
        items = soup.find("div", {"id": "all_votes"}).table.find_all("tr")
    except Exception as e:
        print("ERROR: An error occured while attempting to extract the list items -- {0}".format(e))
    else:
        if not items or len(items) == 0:
            print("WARNING: No list items could be found")
        else:
            # Parse the list items (<tr> elements)
            print("INFO: Parsing {0} list items..".format(len(items)))
            items = [parse_list_item(item) for item in items]
    finally:
        return items


def extract_title(soup):
    title = None
    try:
        title = strip_string(soup.find("h1", {"class": "listPageTitle"}).string)
    except Exception as e:
        print("ERROR: An error occured while attempting to find the list's title -- {0}".format(e))
    else:
        if not title:
            print("WARNING: Title could not be found.")
    finally:
        return title


def strip_string(s):
    control_chars = string.digits + string.ascii_letters + string.punctuation + ' '
    return ''.join(filter(lambda x: x in control_chars, s)).strip()


def parse_list_item(tr):
    data = dict()
    errors = []

    # Get the number of the book
    number = None
    try:
        number = strip_string(tr.find("td", {"class": "number"}).string)
    except Exception as e:
        errors.append("Error finding book number -- {0}".format(e))
    else:
        if not number:
            print("WARNING: List item number could not be found")
    finally:
        data["number"] = number

    # Get it's cover page image URL/data
    img_url, img_data = None, None
    try:
        img_url = tr.find("div", {"data-resource-type": "Book"}).a.img.attrs["src"]
    except Exception as e:
        errors.append("Error finding cover image URL -- {0}".format(e))
    else:
        try:
            img_data = download_img(img_url)
        except Exception as e:
            errors.append("Error downloading cover image URL -- {0}".format(e))
    finally:
        data["img_url"] = img_url
        data["img_data"] = img_data

    # Get the book's title
    title = None
    try:
        title = strip_string(tr.find("a", {"class": "bookTitle"}).span.string)
    except Exception as e:
        errors.append("Error finding list item title -- {0}".format(e))
    else:
        if not title:
            print("WARNING: Could not find list item's title")
    finally:
        data["title"] = title

    # Get the book's author
    author = None
    try:
        author = strip_string(tr.find("a", {"class": "authorName"}).span.string)
    except Exception as e:
        errors.append("Error finding author's name -- {0}".format(e))
    else:
        if not author:
            print("WARNING: Could not find author's name")
    finally:
        data["author"] = author

    # Get the book's rating info
    rating_avg, rating_total = None, None
    try:
        minirating = tr.find("span", {"class": "minirating"}).contents[-1].encode('utf-8').split(b'\xe2\x80\x94') # split on em-dash
        ratings = [x.decode('utf-8').lstrip().split()[0] for x in minirating]
        rating_avg = ratings[0]
        rating_total = ratings[1].replace(',', '')
    except Exception as e:
        errors.append("Error finding rating info -- {0}".format(e))
    finally:
        data["rating_avg"] = rating_avg
        data["rating_total"] = rating_total

    #num_errors = len(errors)
    #if num_errors > 0:
        #print("WARNING: {0} errors were encounted while parsing list item.".format(num_errors))
        #[print("  - {0}".format(err)) for err in errors]

    return data


def scrape_list(list_url):
    book_list = {}
    book_list['url'] = list_url

    # Retrieve HTML
    print("INFO: Retrieving list from {0}..".format(list_url))
    r = requests.get(list_url)
    
    # Raise exception if something went wrong
    if r.status_code != requests.codes.ok:
        r.raise_for_status()

    # Parse the HTML response
    soup = BeautifulSoup(r.content, 'html.parser')
    soup = soup.find("div", {"class": "leftContainer"})

    # Get the list's title
    book_list['title'] = extract_title(soup)

    # Extract list's description
    book_list['description'] = extract_description(soup)

    # Extract list items
    book_list['items'] = extract_list_items(soup)

    return book_list


def run(list_urls):
    lists = {}
    lists['lists'] = [scrape_list(url) for url in list_urls]

    if len(lists['lists']) > 0:
        try:
          with open(OUTPUT_FILE, 'w') as fp:
              json.dump(lists, fp, indent=2)
        except Exception as e:
          print("ERROR: An error occurred while writing results to {0} -- {1}".format(OUTPUT_FILE, e))
            

URL1="https://www.goodreads.com/list/show/2681.Time_Magazine_s_All_Time_100_Novels"
URL2="https://www.goodreads.com/list/show/13086.Goodreads_Top_100_Literary_Novels_of_all_time"
OUTPUT_FILE = 'lists.json'

class ReturnObject(namedtuple('ReturnObject', ['data', 'err'])):
    def __new__(cls, data, err=None):
        return super(ReturnObject, cls).__new__(cls, data, err)

if __name__ == '__main__':
    run([URL1, URL2])
