SELECT
    P.p_name,
    S.s_name,
    C.c_name,
    O.o_orderkey,
    SUBSTRING(P.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier: ', S.s_name, ', Customer: ', C.c_name) AS supplier_and_customer,
    REPLACE(P.p_type, ' ', '_') AS modified_type,
    LENGTH(P.p_name) AS name_length,
    UPPER(SUBSTRING(P.p_mfgr, 1, 5)) AS mfgr_prefix,
    COALESCE(CONCAT(LENGTH(P.p_name), '-', LENGTH(P.p_comment)), 'N/A') AS name_comment_length
FROM
    part P
JOIN
    partsupp PS ON P.p_partkey = PS.ps_partkey
JOIN
    supplier S ON PS.ps_suppkey = S.s_suppkey
JOIN
    lineitem L ON P.p_partkey = L.l_partkey
JOIN
    orders O ON L.l_orderkey = O.o_orderkey
JOIN
    customer C ON O.o_custkey = C.c_custkey
WHERE
    TRIM(P.p_comment) <> ''
    AND S.s_acctbal > 1000
    AND P.p_retailprice BETWEEN 50.00 AND 500.00
ORDER BY
    P.p_name, S.s_name;
