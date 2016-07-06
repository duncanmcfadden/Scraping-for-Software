require 'rubygems'
require 'mechanize'
require 'nokogiri'
require 'open-uri'
require 'domainatrix'

# MODULES

def target_found?(target, page, agent)
  # Check for existance of string in software arg on page defined by url
  # Returns true or false
  # Requires Mechanize agent in global variable $agent
  begin
    if page.body.include? target
      return true
    end
  rescue => e
    puts "Target found?: ERROR on #{url}: #{e}"
  end
  false
end

def find_software(keywords, page, agent)
  # Iterates through list of software strings to check for on page defined by url
  # Returns comma separated value of software strings found, nil if none found
  ret = []
  begin
    keywords.each do | k, v | # Searches keywords hash and returns the corresponding software
      ret << v if target_found?(k, page, agent) # If target_found? returns something, it is added to the return array
    end
  rescue => e
    puts e
  end
  ret.count == 0 ? nil : ret.uniq.join('|') # Returns unique software joined by a "|"
end

# Main module, uses recursion to parse through different depths of a site
def search_page(url, agent, keywords, depth, log_level=1)
  begin
    page = agent.get(url.to_s.downcase) # agent acquires the page.
  rescue => e
    puts "Get page: #{e}"
    return "page not found"
  end
  if !((sf = find_software(keywords, page, agent)) || depth == 0)
    if !page.nil?
        link_array = []
        puts "... iterate over #{page.links.count} links" if log_level>1
        page.links.each do |link| # Loops through each link and appends it to the link array to be searched.
          if link.href.to_s != '' && !link.href.index(' ')
            puts "... ... adding #{link.href}" if log_level>1 # Optional logging
            begin
              if link.href.to_s.index("http") == 0
                link_array << link.href
              else
                puts page.uri.to_s + " : " + link.href.to_s if log_level>1
                link_array << URI.join(page.uri, link.href).to_s
              end
            rescue => e
              puts "link loop: #{e}"
            end
          end
        end
      for page_url in link_array.uniq # Performs search_page on each link in link_array
        if !"#{page_url}".match(/(mailto:|javascript|facebook|instagram|twitter|yelp|youtube|plus.google|pinterest|vimeo|buckley.af|tel:1800|tel:1-800)/)
          puts "... checking #{page_url}" if log_level > 0
          sf = search_page(page_url, agent, keywords, depth-1, log_level) # depth-1 so the function won't call itself forever
          #if sf == "none found" || "page not found"
            #doc = Nokogiri::HTML(open(page_url))
            # Input function for searching iFrame
          #end
          break if !["none found","page not found"].index(sf) # Breaks out of loop if sf isn't "none found" or "page not found"
          sf = nil
        end
      end
    end
  end
  return sf || "none found" # Returns software (sf) or "none found"
end

# Code by Duncan McFadden, reviewed and modified by Nick Walker
