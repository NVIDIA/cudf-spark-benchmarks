WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%special%'
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
), PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CONCAT(p.p_name, ' ', p.p_brand) AS full_description
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%metal%'
)
SELECT 
    hs.s_name,
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    pd.full_description,
    pd.p_retailprice
FROM 
    RankedSuppliers hs
JOIN 
    Partsupp ps ON hs.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    HighValueOrders hvo ON hvo.o_orderkey = ps.ps_partkey
WHERE 
    hs.rank <= 5
ORDER BY 
    hs.s_name, hvo.o_orderdate DESC;
