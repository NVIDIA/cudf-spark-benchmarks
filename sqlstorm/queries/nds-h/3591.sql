WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
CustomerOrders AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
RankedSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name,
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierSummary ss
)
SELECT 
    n.n_name AS nation_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    rs.s_name AS supplier_name,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent < 1000 THEN 'Low Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    nation n 
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    CustomerOrders cs ON c.c_custkey = cs.o_custkey
FULL OUTER JOIN 
    RankedSuppliers rs ON cs.order_count = rs.rank
WHERE 
    (rs.total_supply_cost IS NOT NULL OR cs.total_spent IS NOT NULL)
ORDER BY 
    n.n_name, spending_category, supplier_name;
