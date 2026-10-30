WITH RankedOrders AS (
    SELECT 
        o_orderkey, 
        o_custkey, 
        o_orderstatus, 
        o_orderdate, 
        o_totalprice, 
        ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS rn
    FROM 
        orders 
    WHERE 
        o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
), SupplierPricing AS (
    SELECT 
        ps_partkey, 
        ps_suppkey, 
        SUM(ps_supplycost * ps_availqty) AS total_cost,
        COUNT(*) AS supplier_count
    FROM 
        partsupp
    GROUP BY 
        ps_partkey, 
        ps_suppkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
), TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        DENSE_RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, 
        p.p_name
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    so.total_cost,
    co.c_name,
    tp.p_name,
    tp.revenue,
    CASE 
        WHEN o.o_orderstatus = 'F' THEN 'Finalized'
        WHEN o.o_orderstatus = 'P' AND o.o_totalprice > 1000 THEN 'Pending High Value'
        ELSE 'Pending'
    END AS order_status_desc
FROM 
    RankedOrders o
FULL OUTER JOIN 
    SupplierPricing so ON o.o_orderkey = so.ps_partkey
LEFT JOIN 
    CustomerOrders co ON o.o_custkey = co.c_custkey
INNER JOIN 
    TopParts tp ON so.ps_partkey = tp.p_partkey
WHERE 
    (tp.part_rank <= 5 AND co.total_spent IS NOT NULL) OR 
    (o.o_orderstatus <> 'F' AND co.order_count > 1)
ORDER BY 
    o.o_orderkey DESC, 
    tp.revenue DESC
LIMIT 100;