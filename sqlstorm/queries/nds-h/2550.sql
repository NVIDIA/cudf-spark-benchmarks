
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
        )
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_available_quantity
    FROM 
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    ss.s_name,
    ss.total_parts_supplied,
    ss.total_supply_cost,
    ls.total_sales,
    ls.total_quantity,
    ls.distinct_suppliers
FROM 
    RankedOrders r
LEFT JOIN SupplierStats ss ON ss.total_parts_supplied > 5
JOIN LineItemSummary ls ON r.o_orderkey = ls.l_orderkey
WHERE 
    r.o_orderdate BETWEEN '1997-01-01' AND CURRENT_DATE
    AND ls.total_sales IS NOT NULL
ORDER BY 
    r.o_orderdate DESC,
    r.o_totalprice DESC;
