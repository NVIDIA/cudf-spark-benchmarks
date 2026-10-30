WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT(p.p_name, ' - ', p.p_brand) AS full_description
    FROM 
        part p
),
NationSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items 
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_orderdate
)
SELECT 
    pd.full_description,
    ns.supplier_info,
    sd.o_orderkey,
    sd.total_revenue,
    sd.total_items,
    sd.o_orderdate
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    NationSupplier ns ON ps.ps_suppkey = ns.s_suppkey
JOIN 
    SalesData sd ON pd.p_partkey = sd.o_orderkey
WHERE 
    pd.p_retailprice > 50.00 
    AND sd.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY 
    sd.total_revenue DESC, sd.o_orderdate DESC;