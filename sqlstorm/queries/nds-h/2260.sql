WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
),
SupplierStats AS (
    SELECT DISTINCT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        c.c_mktsegment
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_mktsegment
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        s.total_cost,
        r.r_name
    FROM 
        SupplierStats s
    JOIN 
        supplier sp ON s.s_suppkey = sp.s_suppkey
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.total_cost > 10000
)
SELECT 
    co.c_custkey,
    co.total_orders,
    co.total_spent,
    RANK() OVER (ORDER BY co.total_spent DESC) AS customer_rank,
    ts.s_name AS top_supplier_name,
    ts.total_cost AS supplier_total_cost,
    ts.r_name AS supplier_region
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.total_spent > ts.total_cost
WHERE 
    co.total_orders > (SELECT AVG(total_orders) FROM CustomerOrders)
ORDER BY 
    co.total_spent DESC, customer_rank;