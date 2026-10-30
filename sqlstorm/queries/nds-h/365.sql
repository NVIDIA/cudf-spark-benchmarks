
WITH Supplier_Summary AS (
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
Customer_Order_Summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Order_Details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
Late_Shipments AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS late_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate > l.l_commitdate
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name,
    ss.s_name,
    cs.total_orders,
    cs.total_spent,
    ss.total_avail_qty,
    ss.total_supply_cost,
    od.total_amount,
    COALESCE(ls.late_count, 0) AS late_shipments_count
FROM 
    Customer_Order_Summary cs
JOIN 
    Supplier_Summary ss ON cs.c_custkey = ss.s_suppkey
LEFT JOIN 
    Order_Details od ON cs.total_orders = od.rn
LEFT JOIN 
    Late_Shipments ls ON ls.l_orderkey = od.o_orderkey
WHERE 
    cs.total_spent > (SELECT AVG(total_spent) FROM Customer_Order_Summary)
AND 
    ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM Supplier_Summary)
ORDER BY 
    cs.total_spent DESC, ss.total_supply_cost ASC;
