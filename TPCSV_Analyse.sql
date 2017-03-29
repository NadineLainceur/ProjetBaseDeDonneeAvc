--------------------------------------------------------------------------------
--              LIFBDW2 - 2016-2017 Printemps - TPCSV - ANALYSE
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- #EX1. IMPORT DES DONNEES
--------------------------------------------------------------------------------

SELECT COUNT(*)
FROM TPCSV_ETA_BRUT; -- Résultat : renvoi 202 lignes 

SELECT COUNT(*)
FROM TPCSV_INS_BRUT; -- Résultat : renvoi 2025 lignes --

--------------------------------------------------------------------------------
-- #EX2. CLEF DE TPCSV_ETA_BRUT
--------------------------------------------------------------------------------

----------------------
-- #EX2.Q1.
----------------------

SELECT IDENTIFIANT 
FROM TPCSV_ETA_BRUT; -- Résultat : 199 lignes --

SELECT IDENTIFIANT 
FROM TPCSV_ETA_BRUT 
GROUP BY IDENTIFIANT HAVING COUNT(NVL(IDENTIFIANT,0))>1; -- Résutat : l'identifiant NULL 

----------------------
-- #EX2.Q2.
----------------------

DELETE from TPCSV_ETA_BRUT 
WHERE IDENTIFIANT IS NULL; -- Résutat : 4 lignes supprimé

----------------------
-- #EX2.Q3.
----------------------

SELECT COUNT(IDENTIFIANT)
FROM TPCSV_ETA_BRUT; -- Résultat : 198 lignes --

SELECT DISTINCT COUNT(IDENTIFIANT) 
FROM TPCSV_ETA_BRUT; -- Résultat : 198 lignes --
--Les deux requetes ci-dessus renvoient bien 198 tuples donc IDENTIFIANT est bien clé primaire de la table aprés avoir supprimer l'identifiant Null

--------------------------------------------------------------------------------
-- #EX3. CLEF DE TPCSV_INS_BRUT
--------------------------------------------------------------------------------

----------------------
-- #EX3.Q1.
----------------------

/*
#tuples           : 2025
#établissements   : 78
#années           : 2
#académies        : 28
#domaines         : 5
#disciplines      : 20
*/

----------------------
-- #EX3.Q2.
----------------------

/*     a faire douceument at home 
  CODE_DOMAINE    ?-> NOM_DOMAINE
  NOM_DOMAINE     ?-> CODE_DOMAINE
  CODE_DISCIPLINE ?-> NOM_DISCIPLINE
  NOM_DISCIPLINE  ?-> CODE_DISCIPLINE
  CODE_DISCIPLINE ?-> CODE_DOMAINE
  CODE_DOMAINE    ?-> CODE_DISCIPLINE
*/

----------------------
-- #EX3.Q3.
----------------------

SELECT NUM_ETABLISSEMENT,CODE_DISCIPLINE,ANNEE
FROM TPCSV_INS_BRUT ;

--------------------------------------------------------------------------------
-- #EX4. Nouvelles disciplines
--------------------------------------------------------------------------------

----------------------
-- #EX4.Q1.
----------------------

SELECT DISTINCT NOM_DISCIPLINE FROM TPCSV_INS_BRUT
WHERE ANNEE = 2011 AND NOM_DISCIPLINE NOT IN (SELECT NOM_DISCIPLINE
FROM TPCSV_INS_BRUT WHERE ANNEE = 2010 );

--NOM_DISCIPLINE                                                                                                                 
--------------------------------------------------------------------------------------------------------------------------------
--Masters enseignement                                                                                                             
--Masters enseignement : premier degrÃ©                                                                                            
--Masters enseignement : second degrÃ©, CPE...

----------------------
-- #EX4.Q2.
----------------------

SELECT SUM(NB_REPONSES) 
FROM TPCSV_INS_BRUT 
WHERE CODE_DISCIPLINE = 'disc18' 
MINUS 
SELECT SUM(NB_REPONSES) FROM TPCSV_INS_BRUT 
WHERE CODE_DISCIPLINE = 'disc20' OR CODE_DISCIPLINE = 'disc19';

--------------------------------------------------------------------------------
-- #EX5. Agrégats matérialisés par des disciplines fictives
--------------------------------------------------------------------------------

----------------------
-- #EX5.Q1.
----------------------

CREATE OR REPLACE VIEW DISCIPLINE_AGGREGATS AS
SELECT CODE_DOMAINE, MIN(CODE_DISCIPLINE) AS "CODE_DISC",(COUNT (DISTINCT NOM_DISCIPLINE ) -1 ) AS "NB_DISC" 
FROM TPCSV_INS_BRUT
GROUP BY CODE_DOMAINE
HAVING (COUNT (DISTINCT NOM_DISCIPLINE))>1
ORDER BY MIN(CODE_DISCIPLINE);

----------------------
-- #EX5.Q2.
----------------------

SELECT DISTINCT NOM_DISCIPLINE FROM TPCSV_INS_BRUT WHERE CODE_DISCIPLINE
IN ( SELECT CODE_DISC FROM DISCIPLINE_AGGREGATS ) 
AND NOM_DISCIPLINE LIKE 'Ensemble%';

-- Résultat : 3 tuple car dans le jeu des donné il y'a que 3 disciplnes fictive commencant  
-- par Ensemble et un qui ne commence pas par Ensemble car 'disc18' se nomme ' Master enseignement'

----------------------
-- #EX5.Q3.
----------------------

CREATE OR REPLACE VIEW DOMAINE_AGGREGATS AS
SELECT  RQ2.ANNEE,  RQ2.CODE_DOMAINE, RQ1.NON_FIC AS NB_REPONSE_NON_FICTIVE , RQ2.FIC AS NB_REPONSE_FICTIVE
FROM (SELECT  TP.CODE_DOMAINE,TP.ANNEE , SUM(TP.NB_REPONSES) AS NON_FIC
FROM DISCIPLINE_AGGREGATS VI RIGHT JOIN TPCSV_INS_BRUT TP
ON VI.CODE_DISC = TP.CODE_DISCIPLINE 
WHERE TP.CODE_DISCIPLINE NOT IN  (SELECT CODE_DISCIPLINE FROM  TPCSV_INS_BRUT WHERE CODE_DISCIPLINE=VI.CODE_DISC )
GROUP BY TP.CODE_DOMAINE,TP.ANNEE) RQ1 , 
(SELECT  TP.CODE_DOMAINE,TP.ANNEE , SUM (TP.NB_REPONSES) AS FIC
FROM DISCIPLINE_AGGREGATS VI RIGHT JOIN TPCSV_INS_BRUT TP
ON VI.CODE_DISC = TP.CODE_DISCIPLINE 
WHERE TP.CODE_DISCIPLINE = VI.CODE_DISC 
GROUP BY TP.CODE_DOMAINE,TP.ANNEE) RQ2
WHERE RQ1.ANNEE = RQ2.ANNEE AND RQ1.CODE_DOMAINE = RQ2.CODE_DOMAINE;

--     ANNEE CODE_DOMAINE                                NB_REPONSE_NON_FICTIVE                      NB_REPONSE_FICTIVE
---------- -------------------------- --------------------------------------- ---------------------------------------
--      2010 DEG                                                          22235                                   22235
--      2011 DEG                                                          22976                                   22976
--      2010 STS                                                          16841                                   16841
--      2011 STS                                                          16794                                   16794
--      2011 MEEF                                                         12206                                   12206
--      2010 SHS                                                          12668                                   12668
--      2011 SHS                                                          12438                                   12438

SELECT CODE_DOMAINE, SUM(NB_REPONSE_FICTIVE)- SUM(NB_REPONSE_NON_FICTIVE) AS RESULTAT 
FROM DOMAINE_AGGREGATS 
GROUP BY CODE_DOMAINE;
--la différence est de 0 entres les deux colonnes NB_REPONSE_NON_FICTIVE et NB_REPONSE_FICTIVE 

--------------------------------------------------------------------------------
-- #EX6. Agrégats matérialisés par une université fictive
--------------------------------------------------------------------------------

----------------------
-- #EX6.Q1.
----------------------

SELECT  DISTINCT ANNEE,CODE_DISCIPLINE 
FROM ( SELECT * FROM TPCSV_INS_BRUT WHERE NUM_ETABLISSEMENT = 'UNIV'); --  Résultat : 37 lignes 
SELECT COUNT(*) FROM (SELECT DISTINCT ANNEE,CODE_DISCIPLINE FROM TPCSV_INS_BRUT ); --  Résultat : 37 couples uniques
-- TOUS LES COUPLES ANNEE,CODE_DISCIPLINE ONT LE NUMÉRO D'ÉTABLISSEMENTS 'UNIV'

----------------------
-- #EX6.Q2.
----------------------

CREATE OR REPLACE VIEW UNIV_AGREGATS AS
select 
  T.ANNEE, 
  T.CODE_DISCIPLINE,
  (select sum(NB_REPONSES) from TPCSV_INS_BRUT 
      where ANNEE = T.ANNEE and CODE_DISCIPLINE = T.CODE_DISCIPLINE and NUM_ETABLISSEMENT = 'UNIV') 
  AS NB_UNIV,
  (select sum(NB_REPONSES) from TPCSV_INS_BRUT 
      where ANNEE = T.ANNEE and CODE_DISCIPLINE = T.CODE_DISCIPLINE and NUM_ETABLISSEMENT != 'UNIV')
  AS NB_NON_UNIV,
  (select sum(NB_REPONSES) from TPCSV_INS_BRUT where ANNEE = T.ANNEE and CODE_DISCIPLINE = T.CODE_DISCIPLINE and NUM_ETABLISSEMENT = 'UNIV')
  -
  (select sum(NB_REPONSES) from TPCSV_INS_BRUT where ANNEE = T.ANNEE and CODE_DISCIPLINE = T.CODE_DISCIPLINE and NUM_ETABLISSEMENT != 'UNIV') 
  AS DELTA_UNIV
from TPCSV_INS_BRUT T group by T.ANNEE, T.CODE_DISCIPLINE order by T.ANNEE, T.CODE_DISCIPLINE;

----------------------
-- #EX6.Q3.
----------------------

SELECT ANNEE,CODE_DISCIPLINE 
FROM UNIV_AGREGATS 
WHERE DELTA= 0 ORDER BY ANNEE,CODE_DISCIPLINE ASC;

--		ANNEE CODE_DISCIPLINE          
---------- --------------------------
--      2010 disc03                     
--      2010 disc04                     
--      2010 disc05                     
--      2010 disc06                     
--      2010 disc10                     
--      2010 disc11                     
--      2010 disc14                     
--      2010 disc16                     
--      2010 disc17                     
--      2011 disc01                     
--      2011 disc02                     
--      2011 disc03                     
--      2011 disc04                     
--      2011 disc05                     
--      2011 disc06                     
--      2011 disc07                     
--      2011 disc08                     
--      2011 disc09                     
--      2011 disc10                     
--      2011 disc11                     
--      2011 disc12                     
--      2011 disc13                     
--      2011 disc14                     
--      2011 disc15                     
--      2011 disc16                     
--      2011 disc17                     
--      2011 disc18                     
--      2011 disc19                     
--      2011 disc20

--------------------------------------------------------------------------------
-- #EX7. Vérification de cohérence
--------------------------------------------------------------------------------

----------------------
-- #EX7.Q1.
---------------------

SELECT CODE_DOMAINE, SUM(NB_REPONSES) 
FROM TPCSV_INS_BRUT
WHERE ANNEE = 2011 
AND NUM_ETABLISSEMENT != 'UNIV' 
AND CODE_DISCIPLINE NOT IN ( SELECT CODE_DISC
FROM DISCIPLINE_AGGREGATS )
GROUP BY CODE_DOMAINE;

-- Résultat de la requête:
 
--CODE_DOMAINE               SUM(NB_REPONSES)
-------------------------- ----------------
-- STS                                    8397 
-- SHS                                    6219 
-- MEEF                                   6103 
-- DEG                                   11488 
-- LLA                                    2665 

-- Pourcentage d'erreur : 
--STS 	0.18
--SHS 	0.064
--MEEF 	0.35
--DEG 	0.2
--LLA 	17.7

----------------------
-- #EX7.Q2.
---------------------

SELECT DISTINCT NUM_ETABLISSEMENT 
FROM TPCSV_INS_BRUT 
WHERE NUM_ETABLISSEMENT NOT IN ( SELECT IDENTIFIANT FROM TPCSV_ETA_BRUT );

-- Résultat de la requête : 6 lignes sélectionnées 

--NUM_ETABLISSEMENT        
--------------------------
--0331764N                  
--0341087X                  
--0332929E                  
--0341088Y                  
--0331765P                  
--UNIV