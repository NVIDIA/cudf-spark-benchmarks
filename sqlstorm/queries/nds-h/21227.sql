WITH RecursiveSupply AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        ROW_NUMBER() OVER (ORDER BY rs.total_supply_cost DESC) AS supp_rank
    FROM 
        RecursiveSupply rs
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_discount * l.l_extendedprice ELSE 0 END) AS total_discounted
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    c.c_custkey,
    c.c_name,
    r.r_name AS customer_region,
    COALESCE(ts.supp_rank, 0) AS top_supplier_rank,
    cus.total_spent,
    cus.total_orders,
    cus.total_discounted,
    CASE 
        WHEN cus.total_spent IS NULL THEN 'No Purchases'
        WHEN cus.total_spent >= 1000 THEN 'Premium Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    TopSuppliers ts ON c.c_custkey = ts.s_suppkey
JOIN 
    CustomerOrderSummary cus ON c.c_custkey = cus.c_custkey
WHERE 
    r.r_name IS NOT NULL 
    AND (cus.total_orders > 0 OR cus.total_discounted > 0)
    AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0)
    OR (SELECT COUNT(*) FROM orders o2 WHERE o2.o_custkey = c.c_custkey) > 3
ORDER BY 
    cus.total_spent DESC, 
    customer_region, 
    c.c_custkey;
