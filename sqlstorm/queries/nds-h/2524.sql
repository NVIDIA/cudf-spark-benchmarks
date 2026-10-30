WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.total_cost,
        s.part_count,
        RANK() OVER (ORDER BY s.total_cost DESC) AS cost_rank
    FROM 
        SupplierStats s
),
RankedCustomers AS (
    SELECT 
        os.c_custkey,
        os.total_order_value,
        os.order_count,
        os.last_order_date,
        RANK() OVER (ORDER BY os.total_order_value DESC) AS value_rank
    FROM 
        OrderStats os
)

SELECT 
    rsc.s_suppkey,
    rsc.s_name,
    rsc.total_cost,
    rsc.part_count,
    rcc.c_custkey,
    rcc.total_order_value,
    rcc.order_count,
    rcc.last_order_date
FROM 
    RankedSuppliers rsc
FULL OUTER JOIN 
    RankedCustomers rcc ON rsc.cost_rank = rcc.value_rank
WHERE 
    (rsc.total_cost IS NOT NULL OR rcc.total_order_value IS NOT NULL)
ORDER BY 
    COALESCE(rsc.total_cost, 0) DESC, COALESCE(rcc.total_order_value, 0) DESC;
