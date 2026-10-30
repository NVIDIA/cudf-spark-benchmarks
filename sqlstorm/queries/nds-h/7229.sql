WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_availability,
        RANK() OVER (ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal,
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 10000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
PopularParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_sold,
        RANK() OVER (ORDER BY SUM(l.l_quantity) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name,
    hs.s_name AS top_supplier,
    hc.c_name AS top_customer,
    hp.p_name AS most_popular_part,
    hp.total_sold,
    hs.total_availability
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    RankedSuppliers hs ON n.n_nationkey = hs.s_suppkey
JOIN 
    HighValueCustomers hc ON hc.customer_rank = 1
JOIN 
    PopularParts hp ON hp.part_rank = 1
WHERE 
    r.r_name = 'Asia'
ORDER BY 
    total_sold DESC, total_availability DESC;
