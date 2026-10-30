WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL AND p.p_size > 10
), SupplierPricing AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_supplycost, 
        CASE 
            WHEN ps.ps_supplycost < 100 THEN 'Low'
            WHEN ps.ps_supplycost BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS CostCategory
    FROM 
        partsupp ps 
    WHERE 
        ps.ps_availqty > 0
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        o.o_orderstatus,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND l.l_returnflag = 'N'
), CustomerRegion AS (
    SELECT 
        c.c_custkey, 
        r.r_name AS region_name, 
        SUM(c.c_acctbal) AS total_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey, r.r_name
)
SELECT 
    cr.region_name, 
    SUM(ed.l_extendedprice * (1 - ed.l_discount)) AS total_sales,
    AVG(ed.l_tax) AS avg_tax,
    COUNT(DISTINCT ed.o_orderkey) AS distinct_orders,
    COUNT(rp.p_partkey) AS top_parts_count
FROM 
    OrderDetails ed
LEFT JOIN 
    SupplierPricing sp ON ed.l_partkey = sp.ps_partkey
LEFT JOIN 
    RankedParts rp ON ed.l_partkey = rp.p_partkey AND rp.rn <= 5
JOIN 
    CustomerRegion cr ON ed.o_orderkey = cr.c_custkey
WHERE 
    cr.total_acctbal > (SELECT AVG(total_acctbal) FROM CustomerRegion) 
    AND (ed.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' OR ed.o_orderdate IS NULL)
GROUP BY 
    cr.region_name
HAVING 
    SUM(ed.l_extendedprice) > 1000
ORDER BY 
    total_sales DESC, cr.region_name
LIMIT 10 OFFSET 0;