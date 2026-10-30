WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
), OrderSupplierInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        COALESCE(l.total_lineitem_value, 0) AS lineitem_total,
        COALESCE(s.total_supply_value, 0) AS supply_total
    FROM 
        RankedOrders o
    LEFT JOIN 
        LineItemAggregates l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN 
        SupplierStats s ON l.unique_suppliers = s.supply_count
    WHERE 
        o.order_rank <= 10
)
SELECT 
    r.r_name,
    o.o_orderkey,
    o.o_orderdate,
    o.lineitem_total,
    o.supply_total,
    CASE 
        WHEN o.lineitem_total > o.supply_total THEN 'Lineitem Greater'
        ELSE 'Supply Greater or Equal'
    END AS comparison_result
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    OrderSupplierInfo o ON c.c_custkey = o.o_orderkey
WHERE 
    n.n_comment LIKE '%supplier%'
ORDER BY 
    o.o_orderdate DESC
LIMIT 50;