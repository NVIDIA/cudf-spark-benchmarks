WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, r.r_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    si.nation_name,
    si.region_name,
    SUM(si.part_count) AS total_parts_supplied,
    AVG(si.total_supply_value) AS avg_supply_value_per_supplier,
    COUNT(os.o_orderkey) AS orders_count,
    SUM(os.total_order_value) AS total_sales_value
FROM 
    SupplierInfo si
LEFT JOIN 
    OrderSummary os ON si.s_suppkey = os.o_orderkey
GROUP BY 
    si.nation_name, si.region_name
ORDER BY 
    total_sales_value DESC, total_parts_supplied DESC;