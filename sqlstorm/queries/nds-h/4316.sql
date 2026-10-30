
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders AS o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
), 
SuppliersWithHighCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
CombinedData AS (
    SELECT 
        ro.o_orderkey,
        l.l_partkey,
        s.s_name,
        r.r_name AS supplier_region,
        l.l_extendedprice,
        COALESCE(SUM(swhc.total_supplycost), 0) AS high_cost_total
    FROM 
        lineitem AS l
    JOIN 
        RankedOrders AS ro ON l.l_orderkey = ro.o_orderkey
    LEFT JOIN 
        SuppliersWithHighCosts AS swhc ON l.l_partkey = swhc.ps_partkey
    JOIN 
        supplier AS s ON s.s_suppkey = l.l_suppkey
    JOIN 
        nation AS n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region AS r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        ro.o_orderkey, l.l_partkey, s.s_name, r.r_name, l.l_extendedprice
)
SELECT 
    cd.o_orderkey,
    cd.l_partkey,
    cd.s_name,
    cd.supplier_region,
    cd.l_extendedprice,
    cd.high_cost_total
FROM 
    CombinedData AS cd
WHERE 
    cd.high_cost_total > 0 
    AND cd.l_extendedprice > (SELECT AVG(l.l_extendedprice) FROM lineitem AS l);
