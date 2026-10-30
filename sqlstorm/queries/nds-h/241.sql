
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        si.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierInfo si ON s.s_suppkey = si.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    s.s_name,
    si.nation_name,
    s.s_acctbal,
    CASE 
        WHEN si.total_supply_cost IS NULL THEN 'No supplies'
        ELSE CONCAT('Total Supply Cost: ', CAST(si.total_supply_cost AS STRING))
    END AS supply_info,
    COALESCE(ls.item_count, 0) AS total_items,
    COALESCE(ls.total_price, 0.00) AS total_order_value
FROM 
    HighValueSuppliers s
LEFT JOIN 
    LineItemStats ls ON s.s_suppkey = ls.l_orderkey
LEFT JOIN 
    SupplierInfo si ON s.s_suppkey = si.s_suppkey
WHERE 
    si.total_supply_cost > 10000
ORDER BY 
    s.s_acctbal DESC, 
    total_order_value DESC;
