WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(*) AS line_item_count,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(om.total_order_value), 0) AS total_spent,
        COUNT(om.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        OrderMetrics om ON c.c_custkey = om.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_spent,
    cs.orders_count,
    COALESCE(ss.total_parts, 0) AS total_parts_supplied,
    ss.total_inventory_value,
    ss.avg_acct_balance
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    SupplierStats ss ON cs.c_custkey = ss.s_suppkey
WHERE 
    cs.total_spent > 1000 AND 
    (ss.total_inventory_value IS NOT NULL OR ss.avg_acct_balance IS NOT NULL)
ORDER BY 
    cs.total_spent DESC, 
    cs.orders_count ASC
LIMIT 50;