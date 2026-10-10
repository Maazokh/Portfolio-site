const images = {
    illustrations: 'illustrations_main.jpg',
    concept: 'concept.jpg',
    sketches: 'sketches.jpg',
    pixel: 'pixel.png'
};

// Preload every image into browser cache so transitions are instant
Object.values(images).forEach(src => {
    const img = new Image();
    img.src = src;
});

const navBtns = document.querySelectorAll('.nav-btn');
const layerA = document.getElementById('layer-a');
const layerB = document.getElementById('layer-b');
const imgA = layerA.querySelector('img');
const imgB = layerB.querySelector('img');
const flash = document.getElementById('flash');

let currentTimeout1 = null;
let currentTimeout2 = null;

function switchPose(btn) {
    if (btn.classList.contains('active')) return;

    // Update active button indicator
    const currentActive = document.querySelector('.nav-btn.active');
    if (currentActive) currentActive.classList.remove('active');
    btn.classList.add('active');

    const newPose = btn.getAttribute('data-pose');
    const newSrc = images[newPose];

    // Clear any previous in-flight timeouts for rapid hovering
    if (currentTimeout1) clearTimeout(currentTimeout1);
    if (currentTimeout2) clearTimeout(currentTimeout2);

    // If an animation was mid-transition, sync layer A to current visual
    if (layerB.style.opacity === '1' && imgB.src) {
        imgA.src = imgB.src;
    }
    layerA.style.transition = 'none';
    layerA.style.opacity = '1';
    layerA.style.filter = 'none';

    layerB.style.transition = 'none';
    layerB.style.opacity = '0';
    layerB.style.filter = 'none';

    // 1. Load the new pose into layer B
    imgB.src = newSrc;

    // 2. Fire quick white motion-flash
    flash.style.transition = 'opacity 0.06s ease-in';
    flash.style.opacity = '0.5';

    // 3. Peak flash & start seamless cross-dissolve
    currentTimeout1 = setTimeout(() => {
        // Fade out layer A with subtle motion blur
        layerA.style.transition = 'opacity 0.16s ease-out, filter 0.14s ease-out';
        layerA.style.opacity = '0';
        layerA.style.filter = 'blur(6px)';

        // Fade in layer B simultaneously
        layerB.style.transition = 'opacity 0.16s ease-in, filter 0.16s ease-out';
        layerB.style.opacity = '1';
        layerB.style.filter = 'blur(0px)';

        // Fade flash out
        flash.style.transition = 'opacity 0.18s ease-out';
        flash.style.opacity = '0';
    }, 60);

    // 4. Silently finalize layers after dissolve finishes
    currentTimeout2 = setTimeout(() => {
        imgA.src = newSrc;
        layerA.style.transition = 'none';
        layerA.style.opacity = '1';
        layerA.style.filter = 'none';

        layerB.style.transition = 'none';
        layerB.style.opacity = '0';
        layerB.style.filter = 'none';
    }, 280);
}

// Trigger pose changes on hover (mouseenter) and click
navBtns.forEach(btn => {
    btn.addEventListener('mouseenter', () => switchPose(btn));
    btn.addEventListener('click', () => switchPose(btn));
});
