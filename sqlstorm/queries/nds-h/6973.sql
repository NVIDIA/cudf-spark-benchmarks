WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_nationkey,
        n.n_name AS nation_name,
        r.r_regionkey,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.region_name,
    cr.nation_name,
    sp.s_name,
    SUM(os.total_order_value) AS total_sales_value,
    SUM(sp.total_supply_cost) AS total_supply_cost,
    COUNT(DISTINCT os.o_orderkey) AS distinct_order_count
FROM 
    CustomerRegion cr
JOIN 
    OrderSummary os ON cr.c_custkey = os.o_custkey
JOIN 
    SupplierPartInfo sp ON sp.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_type LIKE '%metal%'
    )
GROUP BY 
    cr.region_name, 
    cr.nation_name, 
    sp.s_name
ORDER BY 
    total_sales_value DESC, 
    distinct_order_count ASC
LIMIT 100;
