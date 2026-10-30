
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
PartRegion AS (
    SELECT 
        p.p_partkey,
        p.p_name AS part_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        p.p_retailprice
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_retailprice > (SELECT COALESCE(AVG(p2.p_retailprice), 0) FROM part p2) 
        AND r.r_name IN ('Europe', 'Asia')
)
SELECT 
    pr.part_name,
    pr.region_name,
    pr.p_retailprice,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    sc.avg_supply_cost
FROM 
    PartRegion pr
LEFT JOIN 
    lineitem lo ON pr.p_partkey = lo.l_partkey 
LEFT JOIN 
    SupplierCost sc ON pr.p_partkey = sc.ps_partkey
WHERE 
    lo.l_shipdate > '1997-01-01' 
GROUP BY 
    pr.part_name, pr.region_name, pr.p_retailprice, sc.avg_supply_cost
HAVING 
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) > (SELECT AVG(total_revenue) FROM (
        SELECT 
            SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
        FROM 
            lineitem 
        WHERE 
            l_shipdate > '1997-01-01' 
        GROUP BY 
            l_orderkey
    ) AS subquery)
ORDER BY 
    total_revenue DESC, pr.region_name;
