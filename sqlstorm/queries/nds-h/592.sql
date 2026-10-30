
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredPartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
)
SELECT 
    fs.c_name,
    fs.order_count,
    fs.total_spent,
    r.s_name AS top_supplier,
    r.s_acctbal AS supplier_balance,
    pp.p_name,
    pp.total_avail_qty,
    CASE 
        WHEN pp.total_avail_qty > 1000 THEN 'High Availability'
        ELSE 'Low Availability' 
    END AS availability_status
FROM 
    CustomerStats fs
JOIN 
    HighValueOrders ho ON fs.c_custkey = ho.o_custkey
LEFT JOIN 
    RankedSuppliers r ON r.supplier_rank = 1 AND ho.o_orderkey = r.s_suppkey
JOIN 
    FilteredPartDetails pp ON pp.p_partkey = ho.o_orderkey
WHERE 
    pp.p_retailprice > (
        SELECT AVG(p.p_retailprice) FROM part p
    )
ORDER BY 
    fs.total_spent DESC, 
    availability_status ASC;
