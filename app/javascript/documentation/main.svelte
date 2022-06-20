<script>
    import { btn, cbtn, dbtn } from "../work/buttons"
    let hidden = true;
    let html = null;
    let details_class = 'border p-3 mt-2';
    let term_class = 'text-blue-500';
    // import { getSignedUrlPromise, s3url } from '../work/aws_helper'
    // let bucket = 'coghealth';
    // let key = 'tjt.bmp'
    // let url = null;
    // let img;
    // let image = new Image();
    // let canvas;
    // let ctx;
    // import { onMount } from 'svelte';
    // onMount(() => {
    //     canvas = document.getElementById('myCanvas');
    //     ctx = canvas.getContext('2d');
    // });
    // // setTimeout( () => getSignedUrlPromise(bucket, key).then( (x) => image.src = x ), 1000 );
    // getSignedUrlPromise(bucket, key).then( (x) => img.src = x );
    // image.onload = function() {
    //   Promise.all([
    //     // Cut out two sprites from the sprite sheet
    //     createImageBitmap(image, 0, 0, 662, 512)
    //   ]).then(function(sprites) {
    //     // Draw each sprite onto the canvas
    //     ctx.drawImage(sprites[0], 0, 0);
    //   });
    // }
</script>

<style>
</style>

<!-- <canvas id="myCanvas" class="resize w-1/4" /> -->
<!-- <div class="w-fullx hx-48 xmx-auto"> -->
<!-- <img bind:this={img} class="object-fill h-48 w-full"/> -->
<!-- </div> -->

<div class="grid grid-cols-4">
    {#if html}
        {@html html}
    {:else}
        <div>
        </div>
    {/if}
    <div class="col-span-3 mr-4">
    <h3 class="text-2xl font-bold mb-2">Projects, Tasks, and Kits</h3>
    <p class="mb-2">
        Starting at a high level, UA has <span class={term_class}>projects</span>.  Each project has <span class={term_class}>tasks</span>,
        and each task has <span class={term_class}>kits</span>.  These relationships are one to many.
        Projects and tasks each have a many to many relationship with <span class={term_class}>users</span>.
        A user can become a member of a project, then a member of a task in that project,
        and then be assigned kits in that task.
    </p>
    <p class="mb-2">
        Permissions can be very complicated, and each url or action taken can have
        its own unique permissions.  Organizing permissions is based on the membership 
        of users in various sorts of groups, either the concept that's literally called <span class={term_class}>group</span>,
         or something  similar.  For example, a project is effectively a group because people can be 
         a member of a project.
    </p>

    <h4>System Admins</h4>
    <p class="mb-2">
        At the highest level is the System Admin, which is generally allowed to perform any action.
        This is reserved for developers setting up the application, and the status 
        can't actually be set via the web interface, only via the database directly
    </p>

    <h4>Portal Manager</h4>
    <p class="mb-2">
        Someone who maintains the application via the application,
        rather than as a developer, and has access to most functions. 
        Most notably, a portal manager can create other portal managers and project managers,
         and has full privileges in all projects and tasks without being a member.
    <p class="mb-2">

    <h4>Project Managers</h4>
    <p class="mb-2">
        Project Managers can create new projects, and list (index) all projects.
        Other users can only list projects they are a member of.
    </p>

    <h4>Project specific permissions</h4>
    <p class="mb-2">
        Some permissions are relative to projects and tasks.
         A user can become a <span class={term_class}>member</span> of a project, and any member could be a
         <span class={term_class}>project owner</span> or <span class={term_class}>project admin</span>.
         The person who creates the project automatically becomes all three.
         The guiding principle is that the person that creates the project wants to
         retain some powers but delegate others, although where to draw the line is
         perhaps arbitrary.  We can summarize as follows:
    </p>

    <details class=details-overlay>
        <summary class="{btn}">Project Owners</summary>
        <div class={details_class}>
            have full power over a project and its tasks.
            Only owners can edit the project properties or promote members to owner or admin status.
        </div>
    </details>
    <details class=details-overlay>
        <summary class="{btn}">Project Admins</summary>
        <div class={details_class}>
            can add members to the project and have full powers over the project's tasks.
            On the project page, admins can see all tasks, members of the project,
            and users outside the project (so they can be added).
        </div>
    </details>
    <details class=details-overlay>
        <summary class="{btn}">Project Members</summary>
        <div class={details_class}>
            have limited powers at the project level.
            They can view (show) the project, and see the tasks they are a member of.
        </div>
    </details>

    <table>
        <tr><th>action</th><th>roles</th></tr>
        <tr><td>change member status</td><td> owner </td></tr>
        <tr><td>edit</td><td>owner</td></tr>
        <tr><td>add/remove members</td><td>admin</td></tr>
        <tr><td>create tasks </td><td>admin</td></tr>
        <tr><td>show</td><td>member</td></tr>
        <tr><td>list</td><td>member, only joined projects</td></tr>
    </table>

    To rephrase:  members of a project can see the project page and a list of the projects they are a member of; when a member is an admin, they can add or remove other users, and create tasks; the owner of the project can promote members to admin status, as well as edit attributes of the project.
    
    <!-- Only admins can delete a project.  A project admin can add or remove users from a project. -->

    <h4>Task permissions</h4>
    <p class="mb-2">
        A project admin can create a task within that project.
        Creating a task doesn't automatically affect memberships however,
        because membership in a task implies working on that task.
        In other words, the user that creates  a task isn't added to that task
        automatically because they may not intend to work on the task.
        A member of a task can also be set as an admin for that task.
    </p>

    <!-- \begin{table}[h]
    \centering
    \begin{tabular}{|l|l|}
    \hline
    action & roles \\ \hline \hline
    create & project admin \\ \hline
    make admin & task admin \\ \hline
    show, edit, delete  & task admin    \\ \hline
    add/remove members & task admin \\ \hline
    list & member \\
          & only joined tasks \\ \hline
    \end{tabular}
    \end{table} -->
    <p class="mb-2">
        Project admins are also considered task admins for the project's  tasks.
        Note that a user's home page lists the tasks they are a member of, across all projects.
    </p>
    
    
    
        <h3>Tasks and Kit Types</h3>
    <p class="mb-2">
        kits
    </p>
    </div>
</div>
