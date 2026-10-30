WITH NationSupplierCosts AS (
    SELECT 
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey AS customer_id,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
TopNations AS (
    SELECT 
        nation,
        total_cost,
        DENSE_RANK() OVER (ORDER BY total_cost DESC) AS rank
    FROM 
        NationSupplierCosts
),
TopCustomers AS (
    SELECT 
        customer_id,
        total_orders,
        total_spent,
        last_order_date,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrderSummary
)
SELECT 
    tn.nation,
    tc.customer_id,
    tc.total_orders,
    tc.total_spent,
    tc.last_order_date
FROM 
    TopNations tn
JOIN 
    TopCustomers tc ON tn.rank = tc.rank
WHERE 
    tn.rank <= 5 AND tc.rank <= 5
ORDER BY 
    tn.total_cost DESC, tc.total_spent DESC;
