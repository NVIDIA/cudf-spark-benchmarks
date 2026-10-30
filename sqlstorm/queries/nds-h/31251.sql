
WITH  OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate) AS order_rank
    FROM
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND 
        o.o_orderdate < DATE '1997-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, 
        ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN SIZE' 
            ELSE CAST(p.p_size AS VARCHAR(255)) 
        END AS part_size_str
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1)
)
SELECT 
    oh.order_rank,
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    p.p_name,
    s.s_name,
    sp.total_avail_qty,
    sp.total_supply_cost,
    COALESCE(n.n_name, 'UNKNOWN') AS supplier_nation
FROM 
    OrderHierarchy oh
LEFT JOIN 
    lineitem l ON l.l_orderkey = oh.o_orderkey
INNER JOIN 
    PartDetails p ON l.l_partkey = p.p_partkey
INNER JOIN 
    SupplierParts sp ON sp.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
WHERE 
    oh.o_totalprice > 1000.00
ORDER BY 
    oh.o_orderdate DESC, 
    p.p_name ASC;
