WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), CustomerStatus AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_totalprice) AS max_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(o.o_orderkey) > 2
), SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplied_parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL 
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), RegionSupplierCount AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
), FinalBenchmark AS (
    SELECT 
        rs.rnk,
        cs.order_count,
        psd.supplied_parts_count,
        rsc.supplier_count,
        COALESCE(cs.max_order_value, 0) AS max_order_value,
        COALESCE(psd.total_supply_value, 0) AS total_supply_value
    FROM 
        RankedOrders rs
    FULL OUTER JOIN 
        CustomerStatus cs ON rs.o_orderkey = cs.c_custkey
    FULL OUTER JOIN 
        SupplierPartDetails psd ON rs.o_orderkey = psd.s_suppkey
    FULL OUTER JOIN 
        RegionSupplierCount rsc ON rs.o_orderkey = rsc.supplier_count
)

SELECT 
    *,
    CASE 
        WHEN rnk IS NULL THEN 'No Rank'
        WHEN max_order_value > total_supply_value THEN 'High Order Value'
        ELSE 'Good Balance'
    END AS performance_category 
FROM 
    FinalBenchmark
WHERE 
    (order_count IS NOT NULL AND order_count > 5)
    OR (supplier_count IS NULL)
ORDER BY 
    performance_category DESC, total_supply_value DESC;
