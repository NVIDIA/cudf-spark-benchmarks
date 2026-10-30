
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.order_count,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > 1000
)
SELECT 
    c.c_name,
    r.r_name,
    psd.ps_partkey,
    l.l_quantity,
    l.l_extendedprice,
    CASE 
        WHEN l.l_discount > 0 THEN (l.l_extendedprice * (1 - l.l_discount)) 
        ELSE l.l_extendedprice 
    END AS final_price,
    CASE 
        WHEN l.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS return_status
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    PartSupplierDetails psd ON l.l_partkey = psd.ps_partkey
LEFT JOIN 
    TopCustomers tc ON c.c_custkey = tc.c_custkey
WHERE 
    psd.supplier_count > 1 AND
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
ORDER BY 
    c.c_name, final_price DESC;
