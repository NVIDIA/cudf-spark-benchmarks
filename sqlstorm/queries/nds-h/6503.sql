WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        AVG(l.l_quantity) AS avg_quantity_per_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.total_supply_cost
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
),
OrdersWithSuppliers AS (
    SELECT 
        os.o_orderkey,
        os.total_revenue,
        os.unique_customers,
        os.avg_quantity_per_order,
        hvs.s_name AS supplier_name,
        hvs.nation_name
    FROM 
        OrderSummary os
    JOIN 
        lineitem l ON os.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        HighValueSuppliers hvs ON ps.ps_suppkey = hvs.s_suppkey
)
SELECT 
    ows.o_orderkey,
    ows.total_revenue,
    ows.unique_customers,
    ows.avg_quantity_per_order,
    ows.supplier_name,
    ows.nation_name
FROM 
    OrdersWithSuppliers ows
ORDER BY 
    ows.total_revenue DESC
LIMIT 10;