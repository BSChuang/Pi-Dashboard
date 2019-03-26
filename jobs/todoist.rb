require "net/http"
require "json"

todoist_token = 'f04ea8df6e7df8b33bfb22d02c5ce2894c2fd204'

SCHEDULER.every '5m', :first_in => 0 do |job|
    
    item_url_string  = 'https://todoist.com/API/v7/sync?token=' + todoist_token + '&resource_types=["items", "projects"]&sync_token=\'*\''
    encoded_item_url_string = URI.encode(item_url_string)

    item_uri = URI.parse(encoded_item_url_string)
    http = Net::HTTP.new(item_uri.host, item_uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(item_uri.request_uri)
    response = http.request(request)



    if response.code == "200"
        result = JSON.parse(response.body)
        
        projects = result['projects']
        projHash = Hash.new;
        projects.each do |proj|
            projHash[proj['id']] = proj['name']
        end

        items = result['items']
        puts items
        items_array = Array[]
        hash = Hash.new
        items.each do |st|
            dateString = st['date_string']
            if dateString != nil
                date = Date.parse(dateString)
                difference = (date - Date.today).to_i
                puts projHash[st['project_id']].to_s
                hash[dateString + " - " + projHash[st['project_id']].to_s + ": " +  + " " + st['content']] = difference
            end
        end
        sorted = hash.sort_by { |name, date| date }
        limit = 0;
        sorted.each do |val|
            if (limit < 3)
                items_array.push(val[0]);
		limit = limit + 1;
            end
        end
        send_event('todoist', {items: items_array})
    else
        puts response.code
        puts response.body
        puts item_url_string
    end
end
