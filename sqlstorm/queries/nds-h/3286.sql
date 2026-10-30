WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        c.c_custkey, c.c_name
),
PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    COALESCE(ss.s_name, 'Unknown Supplier') AS supplier_name,
    ss.total_available AS supplier_total_available,
    ss.avg_supply_cost AS supplier_avg_cost,
    os.c_name AS customer_name,
    os.total_spent AS customer_total_spent,
    os.order_count AS customer_order_count,
    pp.p_name AS part_name,
    pp.order_count AS part_order_count,
    ROW_NUMBER() OVER (PARTITION BY os.c_custkey ORDER BY os.total_spent DESC) AS customer_rank
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    OrderSummary os ON ss.distinct_parts = os.order_count
FULL OUTER JOIN 
    PartPopularity pp ON os.order_count = pp.order_count
WHERE 
    (ss.total_available IS NOT NULL OR os.total_spent IS NOT NULL OR pp.order_count IS NOT NULL)
ORDER BY 
    customer_rank, supplier_avg_cost DESC, part_order_count DESC;