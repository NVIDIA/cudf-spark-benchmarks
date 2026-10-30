WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate, o.o_custkey
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        SUM(o.o_totalprice) > 1000
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM 
        part p
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
)
SELECT 
    tc.c_name,
    tc.c_acctbal,
    pd.p_name,
    pd.total_quantity_sold,
    ss.total_availqty,
    ss.avg_supplycost,
    ro.o_orderdate,
    ro.revenue
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedOrders ro ON tc.c_custkey = ro.o_orderkey
LEFT JOIN 
    ProductDetails pd ON ro.o_orderkey = pd.p_partkey
LEFT JOIN 
    SupplierStats ss ON pd.p_partkey = ss.ps_partkey
WHERE 
    tc.customer_rank <= 5 AND
    (ro.revenue > (SELECT AVG(revenue) FROM RankedOrders) OR ro.revenue IS NULL)
ORDER BY 
    tc.c_name, pd.total_quantity_sold DESC;
