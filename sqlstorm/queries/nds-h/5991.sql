WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        o.o_orderstatus,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status_description
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SupplierOrderSummary AS (
    SELECT 
        sc.s_suppkey,
        od.o_orderkey,
        od.total_order_value,
        od.distinct_parts,
        od.order_status_description
    FROM 
        SupplierCost sc
    JOIN 
        partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        OrderDetails od ON l.l_orderkey = od.o_orderkey
)
SELECT 
    so.s_suppkey,
    COUNT(DISTINCT so.o_orderkey) AS number_of_orders,
    SUM(so.total_order_value) AS total_order_value,
    AVG(so.total_order_value) AS avg_order_value,
    SUM(so.distinct_parts) AS total_distinct_parts,
    SO.order_status_description
FROM 
    SupplierOrderSummary so
GROUP BY 
    so.s_suppkey, so.order_status_description
ORDER BY 
    total_order_value DESC, number_of_orders DESC
LIMIT 10;
