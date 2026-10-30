
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(lines.total_sales) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        (SELECT 
             o.o_orderkey,
             SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales
         FROM 
             orders o
         JOIN 
             lineitem li ON o.o_orderkey = li.l_orderkey
         GROUP BY 
             o.o_orderkey) AS lines ON o.o_orderkey = lines.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(lines.total_sales) > 1000
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT tc.c_custkey) AS unique_customers,
    SUM(sp.total_supply_cost) AS total_supplier_cost,
    AVG(ro.total_sales) AS avg_order_value
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    TopCustomers tc ON c.c_custkey = tc.c_custkey
LEFT JOIN 
    SupplierPerformance sp ON sp.s_suppkey = 
        (SELECT ps.ps_suppkey 
         FROM partsupp ps 
         JOIN part p ON ps.ps_partkey = p.p_partkey 
         WHERE p.p_size >= 10
         LIMIT 1)
LEFT JOIN 
    RankedOrders ro ON tc.c_custkey = ro.o_orderkey
WHERE 
    n.n_name IS NOT NULL
GROUP BY 
    r.r_name
ORDER BY 
    unique_customers DESC, total_supplier_cost DESC;
