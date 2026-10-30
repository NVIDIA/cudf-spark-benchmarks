
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        ns.n_nationkey, 
        ns.n_name AS nation_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_suppkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rn <= 3
),
OrderLineSummary AS (
    SELECT 
        ol.l_orderkey,
        SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS total_price,
        COUNT(DISTINCT ol.l_partkey) AS unique_parts
    FROM 
        lineitem ol
    GROUP BY 
        ol.l_orderkey
),
SupplierOrders AS (
    SELECT 
        so.o_orderkey,
        so.o_orderstatus,
        so.o_totalprice,
        so.o_orderdate,
        so.o_shippriority,
        ts.region_name
    FROM 
        orders so
    LEFT JOIN 
        partsupp ps ON ps.ps_suppkey IN (SELECT s_suppkey FROM TopSuppliers)
    JOIN 
        TopSuppliers ts ON so.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) / 2
    WHERE 
        so.o_totalprice < (SELECT AVG(o_totalprice) FROM orders) 
        OR NULLIF(so.o_orderstatus, 'O') IS NULL
)
SELECT 
    ts.nation_name,
    ts.region_name,
    COUNT(DISTINCT so.o_orderkey) AS num_orders,
    SUM(ol.total_price) AS total_order_value,
    AVG(ol.unique_parts) AS avg_unique_parts_per_order
FROM 
    SupplierOrders so
LEFT JOIN 
    OrderLineSummary ol ON so.o_orderkey = ol.l_orderkey
JOIN 
    TopSuppliers ts ON ts.s_acctbal IS NOT NULL
GROUP BY 
    ts.nation_name, 
    ts.region_name
HAVING 
    COUNT(DISTINCT so.o_orderkey) > 5
ORDER BY 
    total_order_value DESC, 
    ts.nation_name ASC
LIMIT 10 OFFSET 1;
