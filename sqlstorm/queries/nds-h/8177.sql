WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_availqty) AS total_available_qty,
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
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        AVG(l.l_quantity) AS avg_line_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CombinedSummary AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.nation_name,
        os.o_orderkey,
        os.o_custkey,
        os.total_order_value,
        os.avg_line_quantity,
        ss.total_available_qty,
        ss.total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ss.s_suppkey ORDER BY os.total_order_value DESC) AS order_rank
    FROM 
        SupplierSummary ss
    LEFT JOIN 
        OrderSummary os ON ss.s_suppkey = os.o_custkey
)
SELECT 
    cs.s_suppkey,
    cs.s_name,
    cs.nation_name,
    cs.o_orderkey,
    cs.o_custkey,
    cs.total_order_value,
    cs.avg_line_quantity,
    cs.total_available_qty,
    cs.total_supply_cost
FROM 
    CombinedSummary cs
WHERE 
    cs.order_rank <= 5
ORDER BY 
    cs.total_order_value DESC, cs.s_name;
