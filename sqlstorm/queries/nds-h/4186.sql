WITH  SupplierRank AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
TopSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.s_name,
        sr.s_nationkey,
        sr.s_acctbal
    FROM 
        SupplierRank sr
    WHERE 
        sr.rank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        os.total_revenue,
        os.item_count,
        r.r_name
    FROM 
        customer c
    JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.c_custkey,
    co.c_name,
    COALESCE(co.total_revenue, 0) AS total_revenue,
    COALESCE(co.item_count, 0) AS item_count,
    ts.s_name AS top_supplier
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.c_custkey = ts.s_nationkey
WHERE 
    co.total_revenue > 1000
    AND (co.item_count > 5 OR co.total_revenue IS NOT NULL)
ORDER BY 
    co.total_revenue DESC, 
    co.item_count ASC
LIMIT 50;
