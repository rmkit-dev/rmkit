for i in `find ./src/rmkit -iname "*.cpy"`; do 
  ./scripts/docs/add_prototypes.py < $i > $i.new && mv $i.new $i
done
