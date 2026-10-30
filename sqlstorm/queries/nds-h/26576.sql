WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal,
        rs.p_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        tso.p_name,
        COUNT(*) AS num_suppliers,
        AVG(tso.s_acctbal) AS avg_acctbal
    FROM 
        TopSuppliers tso
    GROUP BY 
        tso.p_name
)
SELECT 
    co.c_name,
    co.o_orderkey,
    co.total_spent,
    sd.p_name,
    sd.num_suppliers,
    sd.avg_acctbal
FROM 
    CustomerOrders co
JOIN 
    SupplierDetails sd ON co.total_spent > 1000 AND sd.p_name IN (
        SELECT p.p_name
        FROM part p
        WHERE p.p_retailprice < 50
    )
ORDER BY 
    co.total_spent DESC, sd.avg_acctbal DESC
LIMIT 10;
