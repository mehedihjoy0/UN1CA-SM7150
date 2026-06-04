# https://github.com/pascua28/UN1CA/tree/sixteen/target/a71/patches/display/vendor/etc/qdcm_calib_data_ss_dsi_panel_S6E3FA9_AMB667UM06_FHD.xml

LOG_STEP_IN "- Patching qdcm_calib xmls"
find "$WORK_DIR/vendor/etc" -name "qdcm_calib*.xml" -type f | while read -r QDCM
do
   LOG "Patching: $(basename "$QDCM")"
   EVAL "sed -i -E \
        -e '/Name=\"OEM_HDR\"/ s/>$/ RenderIntent=\"260\">/' \
        -e '/Name=\"native\"/ s/>$/ RenderIntent=\"0\">/' \
        -e '/Name=\"sRGB\"/ s/>$/ RenderIntent=\"0\">/' \
        -e '/Name=\"DISPLAY_P3\"/ s/>$/ RenderIntent=\"0\">/' \
        -e '/Name=\"OEM_HDR10P\"/ s/>$/ RenderIntent=\"261\">/' \
        -e '/Name=\"OEM_HDR_NETFLIX\"/ s/>$/ RenderIntent=\"262\">/' \
        -e '/Name=\"OEM_HDR_AMAZON\"/ s/>$/ RenderIntent=\"263\">/' \
        -e '/Name=\"OEM_VIVID\"/ s/>$/ RenderIntent=\"256\">/' \
        -e '/Name=\"OEM_HDR_1000NIT\"/ s/>$/ RenderIntent=\"264\">/' \
        \"$QDCM\""
done
LOG_STEP_OUT