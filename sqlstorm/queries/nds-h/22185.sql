
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_price
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1994-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
), 
SupplierStats AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS avg_avail_qty
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), 
NationRisk AS (
    SELECT 
        n.n_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_balance
    FROM 
        nation n 
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
), 
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        lineitem l 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    n.n_name AS nation_name,
    s.total_cost AS supplier_total_cost,
    s.part_count AS supplier_part_count,
    (li.total_revenue - COALESCE(s.avg_avail_qty, 0)) AS adjusted_revenue,
    CASE 
        WHEN r.rank_price < 10 THEN 'Top 10%' 
        WHEN r.rank_price >= 10 AND r.rank_price < 20 THEN 'Next 10%' 
        ELSE 'Below Average' 
    END AS order_ranking,
    li.last_ship_date
FROM 
    RankedOrders r
JOIN 
    NationRisk n ON r.o_orderkey = n.order_count
JOIN 
    SupplierStats s ON s.total_cost IS NOT NULL
JOIN 
    LineItemAnalysis li ON li.l_orderkey = r.o_orderkey
WHERE 
    (n.total_balance > 1000 OR n.n_name IS NULL) 
    AND r.o_orderdate IS NOT NULL 
    AND ((li.total_revenue > 5000 AND li.unique_parts > 2) OR 
          (li.total_revenue < 100 AND s.part_count IS NOT NULL AND s.part_count < 5))
ORDER BY 
    r.o_totalprice DESC, 
    n.n_name;
