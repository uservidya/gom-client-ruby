#Ruby Gom Client

##Requirements

* Ruby 1.9

##Usage

### Setup and initialization

```ruby
import gom_client_ruby
GOM = RestFs::Client.new GOM_ROOT
```

Where the GOM_ROOT is of format `"http://<ip/name>:<port>"`.

All further operations are then performed via the initialized object (in this example `GOM`)

###RESTful operations

* GET/retrieve

  * Attribute retrieval:

    ```ruby
    >>> myAttribute = GOM.retrieve("/test:myAttr")    
    {'attribute': {'ctime': '2012-10-12T08:46:48+02:00',
               'mtime': '2012-10-12T08:46:48+02:00',
               'name': 'myAttr',
               'node': '/test',
               'type': 'string',
               'value': 'test'}}
    ```

  * Node retrieval:

    ```ruby
    >>> myNode = GOM.retrieve("/areas")
    {'node': {'ctime': '2012-09-20T04:51:56+02:00',
          'entries': [{'ctime': '2012-07-30T16:13:02+02:00',
                       'mtime': '2012-07-30T16:13:02+02:00',
                       'node': '/areas/home'},
                      {'ctime': '2012-09-29T17:51:47+02:00',
                       'mtime': '2012-09-29T17:51:47+02:00',
                       'node': '/areas/life'},
                      {'ctime': '2012-06-26T21:13:35+02:00',
                       'mtime': '2012-06-26T21:13:35+02:00',
                       'node': '/areas/mobile'},
                      {'ctime': '2012-10-10T18:30:50+02:00',
                       'mtime': '2012-10-10T18:30:50+02:00',
                       'node': '/areas/move'},
                      {'ctime': '2012-09-20T02:19:30+02:00',
                       'mtime': '2012-09-20T02:19:30+02:00',
                       'node': '/areas/pre-show'},
                      {'ctime': '2012-07-30T14:03:57+02:00',
                       'mtime': '2012-07-30T14:03:57+02:00',
                       'node': '/areas/welcome'},
                      {'attribute': {'ctime': '2012-10-11T07:02:18+02:00',
                                     'mtime': '2012-10-11T07:02:18+02:00',
                                     'name': 'operational_mode',
                                     'node': '/areas',
                                     'type': 'string',
                                     'value': 'idle'}}],
          'mtime': '2012-09-20T04:51:56+02:00',
          'uri': '/areas'}}
    ```

  * Retrieval of non-existent Node/Attribute:

    ```ruby
    >>> pprint(GOM.retrieve("/test/does-not-exist"))
    None
    >>> pprint(GOM.retrieve("/test:does-not-exist"))
    None
    ```

* PUT/update

  * Attribute update

    ```ruby
    >>> GOM.update!("/test:temperature", "50 °C")
    '50 °C'
    ```
   
  * Node update

    ```ruby
    >>> GOM.update!("/test/weather", {"temperature": "50 °C", "wind_velocity": "3 km/h", "wind_direction": "NNW"})
    {'status': 201}
    ```

* DELETE/delete

  * Delete existing node
  
    ```ruby
    >>> GOM.destroy("/test/c18bf546-e577-414a-92d2-2ebdfb69b4f6")
    True
    ```

  * Delete non-existing node
  
    ```ruby
    >>> print(GOM.destroy("/test/does-not-exist"))
    None
    ```
  
Attributes are deleted accordingly

* POST/create
  
  * Create empty node
  
   ```ruby
   >>> GOM.create!("/test")
   '/test/c18bf546-e577-414a-92d2-2ebdfb69b4f6'
   ```
  
  * Create node with attributes
  
    ```ruby
    >>> GOM.create!("/test", {"name":"Hans", "profession": "Lumberjack"})
    '/test/419e9db0-2800-43ed-9053-edaafd4f60b3'
    >>> GOM.retrieve("/test/419e9db0-2800-43ed-9053-edaafd4f60b3")
    {'node': {'ctime': '2012-10-12T10:43:25+02:00',
              'entries': [{'attribute': {'ctime': '2012-10-12T10:43:25+02:00',
                                         'mtime': '2012-10-12T10:43:25+02:00',
                                         'name': 'name',
                                         'node': '/test/419e9db0-2800-43ed-9053-edaafd4f60b3',
                                         'type': 'string',
                                         'value': 'Hans'}},
                          {'attribute': {'ctime': '2012-10-12T10:43:25+02:00',
                                         'mtime': '2012-10-12T10:43:25+02:00',
                                         'name': 'profession',
                                         'node': '/test/419e9db0-2800-43ed-9053-edaafd4f60b3',
                                         'type': 'string',
                                         'value': 'Lumberjack'}}],
              'mtime': '2012-10-12T10:43:25+02:00',
              'uri': '/test/419e9db0-2800-43ed-9053-edaafd4f60b3'}}
    ```

##Packaging

##TODO

* Document script runner (run_script)
* Document gom observer creation (register_observer)
