declare -a months=( \
  ["01"]="Jan." \
  ["02"]="Feb." \
  ["03"]="March" \
  ["04"]="April" \
  ["05"]="May" \
  ["06"]="June" \
  ["07"]="July" \
  [10#"08"]="Aug." \
  [10#"09"]="Sept." \
  ["10"]="Oct." \
  ["11"]="Nov." \
  ["12"]="Dec.") \

rm -rf tmp && \

mkdir -p tmp && \
cd ./raw &&

for i in *.tif; do

  month_raw=${i:20:2}
  day_raw=${i:22:2}

  # Project to Azimuthal Equidistant
  gdalwarp -q -t_srs "+proj=aeqd +R=6371000 +lat_0=50 +lon_0=-98" -srcnodata "-99999" $i ../tmp/proj_$i;

  # Some hillshading
  gdaldem hillshade -z -5000 ../tmp/proj_$i ../tmp/hillshade_$i;
  convert -gamma .5 ../tmp/hillshade_$i ../tmp/gamma_$i;
  rm ../tmp/hillshade_$i;

  # Add color relief for places below freezing
  gdaldem color-relief ../tmp/proj_$i ../color-ramp.txt ../tmp/shadedrelief_$i;
  rm ../tmp/proj_$i;

  # Overlay color relief and hillshading
  convert ../tmp/shadedrelief_$i ../tmp/gamma_$i -compose Overlay -composite ../tmp/colored_$i.tif;

  # Add month labels, source
  convert ../tmp/colored_$i.tif \
  -resize 75% \
  -font Helvetica-Bold \
      -size 165x70 \
      -pointsize 24 \
      -fill '#a8a8a8' \
      -weight 1000 \
      -gravity SouthWest \
      -annotate +25+20 "${months[month_raw]} $((10#$day_raw))" \
  -font Helvetica-Bold \
      -pointsize 12 \
      -fill '#a8a8a8' \
      -weight 1000 \
      -gravity SouthEast \
      -annotate +25+15 "Source:\n NOAA Global Forecast System" \
  ../tmp/final_$i.gif

done

cd .. &&

# Convert to GIF
convert -delay 10 -loop 0 ./tmp/*.gif ./vortex.gif