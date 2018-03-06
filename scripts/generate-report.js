#!/usr/bin/env node
/**
 *
 * generate-report.js
 *
 * Example usage:
 *      ./generate-report.js --genome_id=83332.12
 *
 * Author(s):
 *      nconrad
*/

const fs = require('fs'),
    path = require('path'),
    process = require('process'),
    opts = require('commander'),
    rp = require('request-promise'),
    mustache = require('mustache'),
    utils = require('./utils');

const puppeteer = require('puppeteer');

const config = require('../config.json');
const TEMPLATE_PATH = path.resolve(`../${config.templatePath}`);


const pdfMargin = '35px';

const tmplData = {
    author: {
        name: 'nconrad'
    },
    reportDate: new Date().toJSON().slice(0,10).replace(/-/g,'/'),
    getTaxonomy: function() {
        console.log(this)
        let taxonLineage = this.meta.taxon_lineage_names;
        return taxonLineage.slice(1).join(' >> ')
    }
}


if (require.main === module){
    opts.option('-g, --genome_id [value]', 'Genome ID to create report for.')
        .parse(process.argv)

    if (!opts.genome_id) {
        console.error("\nMust provide a genome ID.\n");
        process.exit(1);
    }

    let genomeID = opts.genome_id;

    // fill html template and save as pdf
    buildPdf(genomeID);
}


async function buildPdf(genomeID) {
    let genomeDir = utils.createGenomeDir(genomeID);
    let d = await utils.readFile(`${genomeDir}/${genomeID}-data.json`, 'utf8');
    let reportData = JSON.parse(d);

    // merge in report data
    Object.assign(tmplData, reportData);

    console.log('Reading template...')
    fs.readFile(TEMPLATE_PATH, (err, data) => {
        if (err) throw err;

        console.log('Filling template...');
        let output = mustache.render(data.toString(), tmplData);

        let htmlPath = path.resolve(`${genomeDir}/genome-report.html`);
        console.log(`Writing html to ${htmlPath}...`);
        fs.writeFileSync(htmlPath, output);

        let pdfPath = path.resolve(`${genomeDir}/genome-report.pdf`);
        generatePdf(htmlPath, pdfPath);
    });
}


async function generatePdf(htmlPath, outPath) {
    let browser = await puppeteer.launch({ headless: true } );
    let page = await browser.newPage();
    await page.goto(`file://${htmlPath}`, {waitUntil: 'networkidle2'});

    console.log(`Generating pdf ${outPath}...`)
    await page.pdf({path: outPath, format: 'letter',
        margin: {
            top: pdfMargin,
            left: pdfMargin,
            right: pdfMargin,
            bottom: pdfMargin
        },
        printBackground: true
    });
    await browser.close();

    console.log('Done.');
}


