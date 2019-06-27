require 'git'
g = Git.open('/Users/tesths/Desktop/images')
g.config('user.name', 'twitter robot')
g.config('user.email', 'judi0713@sina.com')
# g.pull
puts g.remotes
# g.add(:all=>true)
# g.commit('message')
#
# g.push()
# g = Git.clone("", "images", :path => '/Users/tesths/Desktop')
