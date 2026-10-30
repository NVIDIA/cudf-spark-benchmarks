
WITH RankedSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        s_nationkey,
        s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank
    FROM 
        supplier
), FilteredParts AS (
    SELECT 
        p_partkey,
        p_name,
        p_brand,
        p_retailprice,
        LOWER(p_comment) AS p_comment_lower
    FROM 
        part
    WHERE 
        p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), DetailedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name AS customer_name,
        n.n_name AS nation_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
)
SELECT 
    R.s_name AS supplier_name,
    P.p_name AS part_name,
    O.o_orderkey,
    O.o_orderdate,
    O.o_totalprice,
    P.p_comment_lower AS processed_comment
FROM 
    RankedSuppliers R
JOIN 
    partsupp PS ON R.s_suppkey = PS.ps_suppkey
JOIN 
    FilteredParts P ON PS.ps_partkey = P.p_partkey
JOIN 
    lineitem L ON PS.ps_partkey = L.l_partkey
JOIN 
    DetailedOrders O ON L.l_orderkey = O.o_orderkey
WHERE 
    R.rank <= 5
ORDER BY 
    R.s_name, O.o_orderdate DESC;
