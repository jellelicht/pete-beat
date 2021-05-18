// SPDX-FileCopyrightText: 2021 bbbbbr
// SPDX-FileCopyrightText: 2021 Jelle Licht <jlicht@fsfe.org>
// 
// SPDX-License-Identifier: MIT

#include <gb/gb.h>
#include "MapInfo.h"
#include "cave_map.h"

void init_gfx(struct MapInfo* mi) {
    // Load Background tiles and then map
    set_bkg_data(0, // TODO: bank?
		 mi->data->tiles->data->num_frames,
		 mi->data->tiles->data->data);
    set_bkg_tiles(0, 0, // TODO: bank? attributes?
		  mi->data->width,
		  mi->data->height,
		  mi->data->data);

    // Turn the background map on to make it visible
    SHOW_BKG;
}

void main(void)
{
    init_gfx(&cave_map);

    // Loop forever
    while(1) {


	// Game main loop processing goes here


	// Done processing, yield CPU and wait for start of next frame
        wait_vbl_done();
    }
}
