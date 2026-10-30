WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        ns.n_name,
        COUNT(DISTINCT rs.s_suppkey) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation ns ON r.r_regionkey = ns.n_regionkey
    LEFT JOIN 
        RankedSuppliers rs ON ns.n_nationkey = rs.s_suppkey
    GROUP BY 
        r.r_regionkey, r.r_name, ns.n_name
),
CustomerOrderSummary AS (
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
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
ProductSupply AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ts.r_name AS region_name,
    ts.n_name AS nation_name,
    COALESCE(cus.total_spent, 0) AS total_spent_by_customers,
    ps.p_name AS product_name,
    ps.total_available,
    ps.average_supply_cost,
    CASE 
        WHEN cus.total_spent IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrderSummary cus ON ts.r_regionkey = ts.r_regionkey
LEFT JOIN 
    ProductSupply ps ON ts.r_regionkey = ps.p_partkey
WHERE 
    ts.total_suppliers > 0
ORDER BY 
    ts.r_name, ts.n_name, total_spent_by_customers DESC;