#!/usr/bin/env bash

# display height and width
D_H=1920
D_W=1408
SIMPLE=/opt/bin/simple
OPKG=/opt/bin/opkg
PROC_NAME=nao

# {{{ FIELD SEPARATOR STUFF
function use_newline_separator() {
    IFS=$(echo -en "\n\b")
}

function use_space_separator() {
    IFS=" "
}

function sanitize() {
    echo "$@" | xargs
}
# }}}

# {{{ CALLBACKS & HANDLERS
function handle_back() {
    if [[ ${RETURN} =~ "back" ]]; then
        BACK
        return 0
    fi
    if [[ ${RETURN} =~ "exit" ]]; then
        exit 0
        return 0
    fi

    return 1
}

function run_cmd() {
    cmd="${*}"
    outfile="/home/root/.cache/nao/output"
    errfile="/home/root/.cache/nao/errors"
    mkdir -p /home/root/.cache/nao/ 2>/dev/null
    LD_PRELOAD= PATH="/opt/bin:$PATH" ${cmd} > "${outfile}" 2> "${errfile}" &
    pid="$!"
    output=`cat "${outfile}" | tail -n50`
    while   ps | grep -v grep | grep " $pid "
    do
        output=`cat "${outfile}" | tail -n50`
        errors=`cat "${errfile}" | tail -n50`
        MAKE_SCENE
        SET timeout 1
        UI "[paragraph 50 50 $(($D_W - 100)) $((D_H - 500)) $output]"
        UI "[paragraph 50 50 $(($D_W - 100)) $((D_H - 500)) $errors]"
        DISPLAY
    done

    wait "${pid}"

    output=`cat "${outfile}"| tail -n50`
    errors=`cat "${errfile}" | tail -n50`
    MAKE_SCENE
    SET timeout 10
    SET justify left
    BACK_BUTTON
    UI "label 50 100 w 50 Finished - returning in 10 seconds"
    UI "[paragraph 50 next $(($D_W - 100)) $((D_H - 500)) ${output}]"
    UI "[paragraph 50 next $(($D_W - 100)) $((D_H - 500)) ${errors}]"
    DISPLAY
}

function do_install() {
    package="${*}"
    run_cmd "${OPKG} install ${package}"
    display_pkg_info "${package}"
}

function do_uninstall() {
    package="${*}"
    run_cmd "${OPKG} remove ${package}"
    display_pkg_info "${package}"
}

function do_list_files() {
    package="${*}"
    run_cmd "${OPKG} files ${package}"
    display_pkg_info "${package}"
}

function get_selected_button() {
    echo `echo "${*}" | sed 's/^selected:\s*//; s/\s* -.*$//'`
}

function get_input_field() {
    echo `cat - | cut -f$1 -d:`
}
# }}}

# {{{ UI BUILDER

function MAKE_SCENE() {
    SCENE=("@fontsize 32")
}

function UI() {
    echo "ADDING LINE: $*"
    SCENE+=("$*")
}

function SET() {
    echo "ADDING LINE: @$*"
    SCENE+=("@$*")
}

function DISPLAY() {
    use_newline_separator
    OUTPUT=`for line in ${SCENE[@]}; do echo $line; done`
    RETURN=`echo "$OUTPUT" | ${SIMPLE}`
    use_space_separator
    SAVED_RETURN=${RETURN}
}

function BACK_BUTTON() {
    UI "button 50 20 200 50 back"
}

function EXIT_BUTTON() {
    UI "button 50 20 200 50 exit"
}

HISTORY=("")
function SHOW_SCENE() {
    scene_line="${*}"
    HISTORY+=("$scene_line")
    $scene_line
}

function BACK() {
    echo "GOING BACK", ${#HISTORY[@]}

    if [[ ${#HISTORY[@]} -le 2 ]]; then
        echo "NO HISTORY, GOING TO MAIN MENU"
        main_menu
    else
        unset HISTORY[-1]
        scene_line=${HISTORY[*]: -1}
        echo "BACK $scene_line"
        $scene_line
    fi
}
# }}}

# {{{ OPKG HELPERS
function list_installed_packages() {
    use_newline_separator
    packages=`${OPKG} list-installed`
    RETURN=`for package in $packages; do echo "$package"; done`
    use_space_separator
}

function list_packages_in_repo() {
    repo="$1"
    pattern=""
    if test -n "$2"; then
        pattern=`sanitize $2`
    fi

    echo "PATTERN IS ${pattern}"

    use_newline_separator
    # package listing from https://github.com/matteodelabre/toltec/issues/5
    if [[ "$CACHED_REPO_NAME" == "$repo" ]]; then
        packages="${CACHED_PACKAGES}"
    else
        echo "GETTING PACKAGES FOR REPO ${repo}"
        packages=`gunzip -c /opt/var/opkg-lists/${repo} | awk '/^Package:/{print $2}'`

    fi
    RETURN=`for package in $packages; do
        if [[ "$package" =~ "${pattern}" ]]; then
            echo "$package";
        fi
    done`

    if test -z "$pattern"; then
        CACHED_PACKAGES=${packages}
        CACHED_REPO_NAME=${repo}
    fi
    use_space_separator
}

function list_packages() {
    use_newline_separator
    # TODO: replace packages with only packages from toltec repo
    packages=`${OPKG} list-installed`
    RETURN=`for package in $packages; do; echo "$package"; done`
    use_space_separator
}
# }}}

# {{{ UI SCENES
function main_menu() {
    MAKE_SCENE
    EXIT_BUTTON
    SET fontsize 64
    SET padding_y 20
    SET justify left
    UI button 20% 200 60% 200 MANAGE PACKAGES
    UI button 20% step 60% 200 SYNC REPOS
    UI button same step 60% 200 CHECK UPGRADES
    UI button same step 60% 200 UPGRADE PACKAGES
    DISPLAY

    echo ${RETURN}

    handle_back

    if [[ ${RETURN} =~ "MANAGE PACKAGES" ]]; then
        echo "LISTING"
        SHOW_SCENE pick_repo
    fi

    if [[ ${RETURN} =~ "MANAGE REPOS" ]]; then
        echo "MANAGING REPOSITORIES"
        SHOW_SCENE repo_menu
    fi

    if [[ ${RETURN} =~ "SYNC REPOS" ]]; then
        echo "SYNCING REPOSITORIES"
        run_cmd "${OPKG} update"
        main_menu
    fi

    if [[ ${RETURN} =~ "UPGRADE PACKAGES" ]]; then
        echo "UPGRADING"
        run_cmd "${OPKG} upgrade"
        main_menu
    fi

    if [[ ${RETURN} =~ "CHECK UPGRADES" ]]; then
        echo "UPGRADING"
        run_cmd "${OPKG} list-upgradable"
        main_menu
    fi


}

function display_pkg_info {
    package="${*}"
    echo "PACKAGE ${package}"
    echo "COMMAND IS ${OPKG} info ${package}"

    if test -z "${package}"; then
        SHOW_SCENE list_menu ${REPO} ${page}
        return
    fi

    info=`${OPKG} info ${package}`
    use_newline_separator

    MAKE_SCENE
    h=200
    UI "label 50 100 0 0 "

    for line in ${info}; do
        UI "[paragraph 50 next 1000 50 ${line}]"
        h=$((h + 50))
    done
    UI ""
    UI "label same next 200 50"
    UI "button 50 next 200 50 Install"
    UI "button next same 200 50 Uninstall"
    UI "button next same 200 50 List Files"


    if test -n "${UNIMPLEMENTED}"; then
        UI "label 50 next $((D_W - 100)) 50 ${UNIMPLEMENTED} is not implemented yet"
    fi

    SET "justify left"
    BACK_BUTTON
    DISPLAY
    UNIMPLEMENTED=""
    handle_back

    # if back wasn't handled then we check to see which button was pressed
    if [[ $? != 0 ]]; then
        if [[ "$RETURN" =~ "selected: Install" ]]; then
            echo "INSTALLING"
            do_install "${package}"
            return
        fi
        if [[ "$RETURN" =~ "selected: List Files" ]]; then
            echo "LISTING FILES"
            do_list_files "${package}"
            return
        fi
        if [[ "$RETURN" =~ "selected: Uninstall" ]]; then
            echo "UNINSTALLING"
            do_uninstall "${package}"
            return
        fi

        UNIMPLEMENTED="${RETURN}"
        SHOW_SCENE display_pkg_info "${*}"
    fi

}

function repo_menu() {
    MAKE_SCENE
    BACK_BUTTON
    UI "label 200 200 500 500 MANAGING REPOS IS NOT IMPLEMENTED YET"
    DISPLAY
    handle_back
}

function list_menu() {
    repo="$1"

    page=0
    if test -n "$2"; then
        page="$2"
    fi
    echo "PAGE IS", $page

    h=200
    page_size=$(( $D_H / 50 - 10 ))
    echo "PAGE SIZE ${page_size} ${D_H} "
    start=$((page*page_size))
    end=$((start+page_size))
    cur=0

    MAKE_SCENE
    SET "justify center"
    UI "label 50 100 $((D_W - 100)) 50 browsing packages in ${REPO}"

    SET "justify left"
    BACK_BUTTON
    has_more=""
    echo "NUM RESULTS ${num_results}"
    pattern="${SEARCH_PATTERN}"
    echo "SEARCH PATTERN IS ${pattern}"
    list_packages_in_repo "${repo}" "${pattern}" # populates #{RETURN}
    use_newline_separator
    for package in ${RETURN}; do
        cur=$((cur + 1))
        if [ $cur -lt $start ]; then
            continue;
        fi

        over=$((end + 1))
        if [ $cur -gt $over ]; then
            echo 'HAS MORE', $cur, $over
            has_more=1
            break
        fi

        UI "button 50 $h $((D_W - 100)) 50 $package"
        h=$((h + 50))
    done


    h=$((h + 50))
    echo "HAS MORE $has_more"
    UI "label 220 25 100 50 search:"
    SET "justify center"
    UI "textinput 350 20 400 50 ${pattern}"
    if [ $page -gt 0 ]; then
        UI "button 800 20 200 50 prev page"
    fi

    if `test -n "${has_more}"`; then
        UI "button 1000 20 200 50 next page"
    fi
    DISPLAY
    # RETURN is filled out after display
    use_space_separator

    if [[ ${RETURN} =~ "input:" ]]; then
        echo "RETURN IS ${RETURN}"
        ref=`echo "${RETURN}" | get_input_field 2`
        search=`echo "${RETURN}" | get_input_field 3`
        SEARCH_PATTERN="${search}"
        echo "SEARCH ${search}"
        list_menu "${REPO}" "${page}"
        return
    fi

    BUTTON=`get_selected_button ${RETURN}` # fills out $BUTTON using $RETURN
    if [[ ${BUTTON} =~ "back" ]]; then
        handle_back
    elif [[ ${BUTTON} =~ "next page" ]]; then
        list_menu ${REPO} $(( page + 1 ))
    elif [[ ${BUTTON} =~ "prev page" ]]; then
        list_menu ${REPO} $(( page - 1 ))
    else
        SHOW_SCENE display_pkg_info "${BUTTON}"
    fi

}

function pick_repo() {
    repos=`ls /opt/var/opkg-lists`
    use_newline_separator
    h=200
    p=50

    MAKE_SCENE
    UI "label 0 100 w 50 Select a repository to browse packages"
    SET "padding_x 20"
    SET "justify left"
    use_newline_separator
    for line in ${repos}; do
        UI "[button $p $h $((D_W-2*$p)) 50 ${line}]"
        h=$((h + 50))
    done
    UI ""
    BACK_BUTTON
    DISPLAY

    BUTTON=`get_selected_button ${RETURN}`
    if [[ ${BUTTON} =~ "back" ]]; then
        handle_back
    else
        REPO=${BUTTON}
        SHOW_SCENE list_menu ${REPO} 0
    fi
    use_space_separator
}
# }}}

REPO="entware"

function killall_nao() {
    pids=`ps | grep ${PROC_NAME} | grep -v $$ | grep bash | awk '{print $1}'`
    if test -z "$pids"; then
        return
    fi

    echo "BYE BYE NAO, KILLING ${pids}"
    kill ${pids}
}

killall_nao
SHOW_SCENE pick_repo

# vim set foldmethod=marker
