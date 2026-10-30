WITH SupplierPrices AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spending
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartRanking AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        pr.revenue
    FROM 
        part p
    JOIN 
        PartRanking pr ON p.p_partkey = pr.l_partkey
    WHERE 
        pr.rank <= 10
)
SELECT 
    n.n_name, 
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    SUM(sp.total_cost) AS total_supplier_cost,
    AVG(tp.revenue) AS avg_top_part_revenue
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    HighValueCustomers hvc ON c.c_custkey = hvc.c_custkey
LEFT JOIN 
    SupplierPrices sp ON sp.s_suppkey IN (
        SELECT p.ps_suppkey FROM partsupp p
        JOIN TopParts tp ON p.ps_partkey = tp.p_partkey
    )
LEFT JOIN 
    TopParts tp ON tp.p_partkey IN (
        SELECT l.l_partkey FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O'
        )
    )
GROUP BY 
    n.n_name
ORDER BY 
    n.n_name;
