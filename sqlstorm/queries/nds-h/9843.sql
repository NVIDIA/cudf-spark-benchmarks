WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopSpendingCustomers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        RankedOrders o
    JOIN 
        customer c ON o.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        r.r_name, n.n_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT 
    t.region_name,
    t.nation_name,
    t.total_spent,
    t.order_count,
    sp.supplier_name,
    sp.part_name,
    sp.ps_supplycost,
    sp.ps_availqty
FROM 
    TopSpendingCustomers t
JOIN 
    SupplierPartDetails sp ON t.region_name = 'AMERICA' 
WHERE 
    t.total_spent > 1000000 
ORDER BY 
    t.total_spent DESC, sp.ps_supplycost ASC
LIMIT 10;